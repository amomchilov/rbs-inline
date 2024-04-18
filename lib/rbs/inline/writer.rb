module RBS
  module Inline
    class Writer
      attr_reader :output
      attr_reader :writer

      def initialize(buffer = +"")
        @output = buffer
        @writer = RBS::Writer.new(out: StringIO.new(buffer))
      end

      def self.write(uses, decls)
        writer = Writer.new()
        writer.write(uses, decls)
        writer.output
      end

      def write(uses, decls)
        rbs = decls.filter_map do |decl|
          translate_decl(decl)
        end

        writer.write(rbs)
      end

      def translate_decl(decl)
        case decl
        when AST::Declarations::ClassDecl
          translate_class_decl(decl)
        when AST::Declarations::ModuleDecl
          translate_module_decl(decl)
        end
      end

      def translate_class_decl(decl)
        return unless decl.class_name

        if decl.comments
          comment = RBS::AST::Comment.new(string: decl.comments.content, location: nil)
        end

        members = [] #: Array[RBS::AST::Members::t | RBS::AST::Declarations::t]

        decl.members.each do |member|
          if member.is_a?(AST::Members::Base)
            if rbs_member = translate_member(member)
              members.concat rbs_member
            end
          end

          if member.is_a?(AST::Declarations::Base)
            if rbs = translate_decl(member)
              members << rbs
            end
          end
        end

        RBS::AST::Declarations::Class.new(
          name: decl.class_name,
          type_params: [],
          members: members,
          super_class: decl.super_class,
          annotations: [],
          location: nil,
          comment: comment
        )
      end

      def translate_module_decl(decl)
        return unless decl.module_name

        if decl.comments
          comment = RBS::AST::Comment.new(string: decl.comments.content, location: nil)
        end

        members = [] #: Array[RBS::AST::Members::t | RBS::AST::Declarations::t]

        decl.members.each do |member|
          if member.is_a?(AST::Members::Base)
            if rbs_member = translate_member(member)
              members.concat rbs_member
            end
          end

          if member.is_a?(AST::Declarations::Base)
            if rbs = translate_decl(member)
              members << rbs
            end
          end
        end

        RBS::AST::Declarations::Module.new(
          name: decl.module_name,
          type_params: [],
          members: members,
          self_types: [],
          annotations: [],
          location: nil,
          comment: comment
        )
      end

      def translate_member(member)
        case member
        when AST::Members::RubyDef
          if member.comments
            comment = RBS::AST::Comment.new(string: member.comments.content, location: nil)
          end

          [
            RBS::AST::Members::MethodDefinition.new(
              name: member.method_name,
              kind: member.method_kind,
              overloads: member.method_overloads,
              annotations: member.method_annotations,
              location: nil,
              comment: comment,
              overloading: false,
              visibility: nil
            )
          ]
        when AST::Members::RubyAlias
          if member.comments
            comment = RBS::AST::Comment.new(string: member.comments.content, location: nil)
          end

          [
            RBS::AST::Members::Alias.new(
              new_name: member.new_name,
              old_name: member.old_name,
              kind: :instance,
              annotations: [],
              location: nil,
              comment: comment
            )
          ]
        when AST::Members::RubyMixin
          [member.rbs].compact
        when AST::Members::RubyAttr
          member.rbs
        end
      end
    end
  end
end